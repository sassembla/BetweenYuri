//
//  BetweenYuriApp.swift
//  BetweenYuri
//
//  Created by aimer on 2024/08/29.
//
import Foundation
import SwiftUI

import UserNotifications

@main
struct BetweenYuriApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {}

    var body: some Scene {
        Settings {
            EmptyView() // ダミーの設定用ウィンドウ。表示されない
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // アプリケーションの起動時に呼ばれる。Appの起動を制限する。
        print("Application did finish launching")

        // 他の NSApplication 関連のコードをここに記述
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == Bundle.main.bundleIdentifier && $0 != NSRunningApplication.current
        }

        if isRunning {
            NSApp.terminate(nil)
        }

        // url schemeのレシーバを起動
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // 特定フォルダアクセスを獲得
        requestFolderAccess()
    }

    // urlSchemeが発動したら、設定しておいたフォルダにファイルを吐く。常に上書きされる。
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
           let url = URL(string: urlString)
        {
            print("Received URL: \(url)")

            // URLSchemeを特定フォルダに吐き出す。
            updateFileContent(data: urlString)
        }
    }

    func updateFileContent(data: String) {
        guard let folderPath = UserDefaults.standard.string(forKey: "selectedFolderPath") else {
            print("No folder selected.")
            return
        }

        let fileURL = URL(fileURLWithPath: folderPath).appendingPathComponent("URLSchemeFile")
        let newContent = data

        do {
            try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File updated successfully.")
        } catch {
            print("Failed to update file: \(error)")
        }
    }

    // ウィンドウがゼロになってもアプリケーションを閉じない。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func requestFolderAccess() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Select a Folder"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                // 選択されたフォルダのURLを保存
                UserDefaults.standard.set(url.path, forKey: "selectedFolderPath")
                print("Folder selected: \(url.path)")
            } else {
                print("Folder selection was canceled or failed.")
            }
        }
    }
}
