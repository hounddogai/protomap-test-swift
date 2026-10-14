@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierLedgerStore = Labs.newMemoryCourierLedgerStore()
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
