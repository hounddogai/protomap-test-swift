@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultAdjustmentStore = Labs.newMemoryResultAdjustmentStore()
        let item = Labs.newResultAdjustment("code-604", name: "name-292")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
