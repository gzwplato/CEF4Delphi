// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2017 Salvador D�az Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uCEFBaseRefCounted;

{$IFNDEF CPUX64}
  {$ALIGN ON}
  {$MINENUMSIZE 4}
{$ENDIF}

{$I cef.inc}

interface

uses
  uCEFInterfaces;

type
  TCefBaseRefCountedOwn = class(TInterfacedObject, ICefBaseRefCounted)
    protected
      FData: Pointer;

    public
      constructor CreateData(size: Cardinal; owned: Boolean = False); virtual;
      destructor  Destroy; override;
      function    Wrap: Pointer;
  end;

  TCefBaseRefCountedRef = class(TInterfacedObject, ICefBaseRefCounted)
    protected
      FData: Pointer;

    public
      constructor Create(data: Pointer); virtual;
      destructor  Destroy; override;
      function    Wrap: Pointer;
      class function UnWrap(data: Pointer): ICefBaseRefCounted;
  end;



implementation

uses
  uCEFTypes, uCEFMiscFunctions;

procedure cef_base_add_ref(self: PCefBaseRefCounted); stdcall;
begin
  TCefBaseRefCountedOwn(CefGetObject(self))._AddRef;
end;

function cef_base_release(self: PCefBaseRefCounted): Integer; stdcall;
begin
  Result := TCefBaseRefCountedOwn(CefGetObject(self))._Release;
end;

function cef_base_has_one_ref(self: PCefBaseRefCounted): Integer; stdcall;
begin
  Result := Ord(TCefBaseRefCountedOwn(CefGetObject(self)).FRefCount = 1);
end;

procedure cef_base_add_ref_owned(self: PCefBaseRefCounted); stdcall;
begin
  //
end;

function cef_base_release_owned(self: PCefBaseRefCounted): Integer; stdcall;
begin
  Result := 1;
end;

function cef_base_has_one_ref_owned(self: PCefBaseRefCounted): Integer; stdcall;
begin
  Result := 1;
end;

constructor TCefBaseRefCountedOwn.CreateData(size: Cardinal; owned: Boolean);
begin
  GetMem(FData, size + SizeOf(Pointer));
  PPointer(FData)^ := Self;
  Inc(PByte(FData), SizeOf(Pointer));
  FillChar(FData^, size, 0);
  PCefBaseRefCounted(FData)^.size := size;

  if owned then
    begin
      PCefBaseRefCounted(FData)^.add_ref     := cef_base_add_ref_owned;
      PCefBaseRefCounted(FData)^.release     := cef_base_release_owned;
      PCefBaseRefCounted(FData)^.has_one_ref := cef_base_has_one_ref_owned;
    end
   else
    begin
      PCefBaseRefCounted(FData)^.add_ref     := cef_base_add_ref;
      PCefBaseRefCounted(FData)^.release     := cef_base_release;
      PCefBaseRefCounted(FData)^.has_one_ref := cef_base_has_one_ref;
    end;
end;

destructor TCefBaseRefCountedOwn.Destroy;
var
  TempPointer : pointer;
begin
  TempPointer := FData;
  FData       := nil;

  Dec(PByte(TempPointer), SizeOf(Pointer));
  FreeMem(TempPointer);

  inherited Destroy;
end;

function TCefBaseRefCountedOwn.Wrap: Pointer;
begin
  Result := FData;

  if (FData <> nil) and Assigned(PCefBaseRefCounted(FData)^.add_ref) then
    PCefBaseRefCounted(FData)^.add_ref(PCefBaseRefCounted(FData));
end;

// TCefBaseRefCountedRef

constructor TCefBaseRefCountedRef.Create(data: Pointer);
begin
  Assert(data <> nil);
  FData := data;
end;

destructor TCefBaseRefCountedRef.Destroy;
begin
  if (FData <> nil) and Assigned(PCefBaseRefCounted(FData)^.release) then
    PCefBaseRefCounted(FData)^.release(PCefBaseRefCounted(FData));

  inherited Destroy;
end;

class function TCefBaseRefCountedRef.UnWrap(data: Pointer): ICefBaseRefCounted;
begin
  if (data <> nil) then
    Result := Create(data) as ICefBaseRefCounted
   else
    Result := nil;
end;

function TCefBaseRefCountedRef.Wrap: Pointer;
begin
  Result := FData;

  if (FData <> nil) and Assigned(PCefBaseRefCounted(FData)^.add_ref) then
    PCefBaseRefCounted(FData)^.add_ref(PCefBaseRefCounted(FData));
end;

end.
