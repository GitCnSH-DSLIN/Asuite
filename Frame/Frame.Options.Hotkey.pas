{
Copyright (C) 2006-2020 Matteo Salvi

Website: http://www.salvadorsoftware.com/

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

unit Frame.Options.Hotkey;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DKLang, Frame.BaseEntity, VirtualTrees,
  Vcl.ComCtrls, Vcl.StdCtrls, Lists.Base, Vcl.Menus, Vcl.ExtCtrls, Vcl.Themes;

type
  TfrmHotkeyOptionsPage = class(TfrmBaseEntityPage)
    DKLanguageController1: TDKLanguageController;
    gbHotkey: TGroupBox;
    lblHotkeyWindow: TLabel;
    lblHotkeyGM: TLabel;
    cbHotKey: TCheckBox;
    grpOrderSoftware: TGroupBox;
    vstItems: TVirtualStringTree;
    pmHotkey: TPopupMenu;
    mniEditHotkey: TMenuItem;
    mniRemoveHotkey: TMenuItem;
    mniN1: TMenuItem;
    mniProperties: TMenuItem;
    lblHotkeyCM: TLabel;
    edtHotkeyMF: TButtonedEdit;
    edtHotkeyGM: TButtonedEdit;
    edtHotkeyCM: TButtonedEdit;
    procedure cbHotKeyClick(Sender: TObject);
    procedure mniEditHotkeyClick(Sender: TObject);
    procedure mniRemoveHotkeyClick(Sender: TObject);
    procedure mniPropertiesClick(Sender: TObject);
    procedure edtHotkeyClick(Sender: TObject);
    procedure edtHotkeyChange(Sender: TObject);
    procedure edtHotkeyClear(Sender: TObject);
  private
    { Private declarations }
    procedure LoadGlyphs;
    procedure SaveInHotkeyItemList(const ATree: TBaseVirtualTree;const AItemList: TBaseItemsList);
  strict protected
    function GetTitle: string; override;
    function GetImageIndex: Integer; override;
    function InternalLoadData: Boolean; override;
    function InternalSaveData: Boolean; override;
  public
    { Public declarations }
  end;

var
  frmHotkeyOptionsPage: TfrmHotkeyOptionsPage;

implementation

uses
  AppConfig.Main, VirtualTree.Events, VirtualTree.Methods, NodeDataTypes.Custom,
  Forms.ShortcutGrabber, HotkeyManager, DataModules.Icons, System.UITypes;

{$R *.dfm}

{ TfrmHotkeyOptionsPage }

procedure TfrmHotkeyOptionsPage.cbHotKeyClick(Sender: TObject);
begin
  edtHotkeyMF.Enabled := cbHotKey.Checked;
  edtHotkeyGM.Enabled := cbHotKey.Checked;
  edtHotkeyCM.Enabled := cbHotKey.Checked;
end;

procedure TfrmHotkeyOptionsPage.edtHotkeyClick(Sender: TObject);
var
  strHotkey: string;
begin
  if Sender is TButtonedEdit then
  begin
    strHotkey := TfrmShortcutGrabber.Execute(Self, TButtonedEdit(Sender).Text);
    if (strHotkey <> '') then
    begin
      TButtonedEdit(Sender).Text := strHotkey;

      if (Sender <> edtHotkeyMF) and (edtHotkeyMF.Text = strHotkey) then
        edtHotkeyMF.Text := '';

      if (Sender <> edtHotkeyGM) and (edtHotkeyGM.Text = strHotkey) then
        edtHotkeyGM.Text := '';

      if (Sender <> edtHotkeyCM) and (edtHotkeyCM.Text = strHotkey) then
        edtHotkeyCM.Text := '';
    end;
  end;
end;

procedure TfrmHotkeyOptionsPage.edtHotkeyChange(Sender: TObject);
var
  edtHotkey: TButtonedEdit;
begin
  if Sender is TButtonedEdit then
  begin
    edtHotkey := TButtonedEdit(Sender);
    edtHotkey.RightButton.Visible := edtHotkey.Text <> '';
  end;
end;

procedure TfrmHotkeyOptionsPage.edtHotkeyClear(Sender: TObject);
begin
  if Sender is TButtonedEdit then
    TButtonedEdit(Sender).Text := '';
end;

function TfrmHotkeyOptionsPage.GetImageIndex: Integer;
begin
  Result := Config.IconsManager.GetIconIndex('hotkey');
end;

function TfrmHotkeyOptionsPage.GetTitle: string;
begin
  Result := DKLangConstW('msgHotkey');
end;

function TfrmHotkeyOptionsPage.InternalLoadData: Boolean;
begin
  Result := inherited;
  TVirtualTreeEvents.Create.SetupVSTHotkey(vstItems);

  //Hot Keys
  cbHotKey.Checked := Config.HotKey;
  edtHotkeyMF.Text := HotKeyToText(Config.WindowHotKey, False);
  edtHotkeyGM.Text := HotKeyToText(Config.GraphicMenuHotkey, False);
  edtHotkeyCM.Text := HotKeyToText(Config.ClassicMenuHotkey, False);

  //Populate VST with HotKeyItemList's items
  TVirtualTreeMethods.Create.PopulateVSTItemList(vstItems, Config.ListManager.HotKeyItemList);
  vstItems.SortTree(0, sdAscending);
  vstItems.Header.AutoFitColumns;

  //Enable/disable visual components
  cbHotKeyClick(Self);
  LoadGlyphs;

  //Hide caret in hotkey control
  HideCaret(edtHotkeyMF.Handle);
  HideCaret(edtHotkeyGM.Handle);
  HideCaret(edtHotkeyCM.Handle);

  edtHotkeyMF.Color := StyleServices.GetSystemColor(edtHotkeyMF.Color);
  edtHotkeyGM.Color := StyleServices.GetSystemColor(edtHotkeyGM.Color);
  edtHotkeyCM.Color := StyleServices.GetSystemColor(edtHotkeyCM.Color);
end;

function TfrmHotkeyOptionsPage.InternalSaveData: Boolean;
begin
  Result := inherited;
  //Hot Keys
  Config.HotKey       := cbHotKey.Checked;
  Config.WindowHotKey := TextToHotKey(edtHotkeyMF.Text, False);
  Config.GraphicMenuHotkey := TextToHotKey(edtHotkeyGM.Text, False);
  Config.ClassicMenuHotkey := TextToHotKey(edtHotkeyCM.Text, False);
  //Save vst items in HotKeyItemList
  SaveInHotkeyItemList(vstItems, Config.ListManager.HotKeyItemList);
end;

procedure TfrmHotkeyOptionsPage.LoadGlyphs;
begin
  edtHotkeyMF.Images := dmImages.ilSmallIcons;
  edtHotkeyGM.Images := dmImages.ilSmallIcons;
  edtHotkeyCM.Images := dmImages.ilSmallIcons;

  mniRemoveHotkey.ImageIndex := Config.IconsManager.GetIconIndex('keyboard_delete');
  mniEditHotkey.ImageIndex   := Config.IconsManager.GetIconIndex('keyboard_edit');
  mniProperties.ImageIndex   := Config.IconsManager.GetIconIndex('property');

  edtHotkeyMF.RightButton.ImageIndex := Config.IconsManager.GetIconIndex('cancel');
  edtHotkeyGM.RightButton.ImageIndex := Config.IconsManager.GetIconIndex('cancel');
  edtHotkeyCM.RightButton.ImageIndex := Config.IconsManager.GetIconIndex('cancel');
end;

procedure TfrmHotkeyOptionsPage.mniEditHotkeyClick(Sender: TObject);
var
  ShortCut: string;
  NodeData: TvCustomRealNodeData;
begin
  if Assigned(vstItems.FocusedNode) then
  begin
    NodeData := TvCustomRealNodeData(TVirtualTreeMethods.Create.GetNodeItemData(vstItems.FocusedNode, vstItems));
    if Assigned(NodeData) then
    begin
      ShortCut := TfrmShortcutGrabber.Execute(Self, HotKeyToText(NodeData.Hotkey, False));
      if (ShortCut <> '') then
      begin
        NodeData.Hotkey  := TextToHotKey(ShortCut, false);
        NodeData.ActiveHotkey := True;
        NodeData.Changed := True;

        if (edtHotkeyMF.Text = ShortCut) then
          edtHotkeyMF.Text := '';

        if (edtHotkeyGM.Text = ShortCut) then
          edtHotkeyGM.Text := '';

        if (edtHotkeyCM.Text = ShortCut) then
          edtHotkeyCM.Text := '';
      end;
    end;
  end;
end;

procedure TfrmHotkeyOptionsPage.mniPropertiesClick(Sender: TObject);
begin
  TVirtualTreeMethods.Create.ShowItemProperty(Self, vstItems, vstItems.FocusedNode, False);
end;

procedure TfrmHotkeyOptionsPage.mniRemoveHotkeyClick(Sender: TObject);
begin
  if (MessageDlg((DKLangConstW('msgConfirm')),mtWarning, [mbYes,mbNo], 0) = mrYes) then
    if Assigned(vstItems.FocusedNode) then
      vstItems.IsVisible[vstItems.FocusedNode] := False;
end;

procedure TfrmHotkeyOptionsPage.SaveInHotkeyItemList(
  const ATree: TBaseVirtualTree; const AItemList: TBaseItemsList);
var
  Node : PVirtualNode;
  NodeData: TvCustomRealNodeData;
begin
  Node := ATree.GetFirst;
  while Assigned(Node) do
  begin
    NodeData := TvCustomRealNodeData(TVirtualTreeMethods.Create.GetNodeItemData(Node, ATree));
    if Assigned(NodeData) then
    begin
      NodeData.ActiveHotkey := ATree.IsVisible[Node];
      if NodeData.ActiveHotkey then
        AItemList.AddItem(NodeData)
      else
        AItemList.RemoveItem(NodeData);
      NodeData.Changed := True;
    end;
    Node := ATree.GetNext(Node);
  end;
end;

end.
