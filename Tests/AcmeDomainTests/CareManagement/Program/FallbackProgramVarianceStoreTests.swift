@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackProgramVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackProgramVarianceStore = CareManagement.newMemoryFallbackProgramVarianceStore()
        let item = CareManagement.newFallbackProgramVariance("code-105", title: "title-132")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
