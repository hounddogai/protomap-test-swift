@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingReferenceRangeRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingReferenceRangeRollupStore = Labs.newMemoryRollingReferenceRangeRollupStore()
        let item = Labs.newRollingReferenceRangeRollup("code-385", label: "label-981")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
