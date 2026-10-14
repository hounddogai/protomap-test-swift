@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyCourierEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyCourierEstimateStore = Labs.newMemoryLegacyCourierEstimateStore()
        let item = Labs.newLegacyCourierEstimate("code-566", name: "name-702")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
