@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyProgramVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyProgramVarianceStore = CareManagement.newMemoryLegacyProgramVarianceStore()
        let item = CareManagement.newLegacyProgramVariance("code-983", title: "title-805")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
