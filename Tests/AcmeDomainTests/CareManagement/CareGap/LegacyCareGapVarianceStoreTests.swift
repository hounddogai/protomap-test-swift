@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyCareGapVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyCareGapVarianceStore = CareManagement.newMemoryLegacyCareGapVarianceStore()
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
