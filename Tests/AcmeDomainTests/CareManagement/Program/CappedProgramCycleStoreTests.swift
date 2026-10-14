@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedProgramCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedProgramCycleStore = CareManagement.newMemoryCappedProgramCycleStore()
        let item = CareManagement.newCappedProgramCycle("code-910", label: "label-110")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
