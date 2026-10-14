@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramVarianceStore = CareManagement.newMemoryProgramVarianceStore()
        let item = CareManagement.newProgramVariance("code-979", label: "label-37")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
