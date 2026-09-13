import Testing
@testable import ClipboardManagerCore

struct ExpirationTests {
    @Test func sessionHasNoExpiration() {
        let store = ClipboardHistoryStore(settings: ClipboardSettings(retentionPeriod: .session))
        store.add(text: "Hello")
        #expect(store.items[0].expiresAt == nil)
    }

    @Test func timedRetentionHasExpiration() {
        let store = ClipboardHistoryStore(settings: ClipboardSettings(retentionPeriod: .fiveMinutes))
        store.add(text: "Hello")
        #expect(store.items[0].expiresAt != nil)
    }
}
