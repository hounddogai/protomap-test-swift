@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingResultThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingResultThresholdStore = Labs.newMemoryRollingResultThresholdStore()
        let item = Labs.newRollingResultThreshold("code-830", name: "name-196")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
