@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveProgramCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveProgramCycleStore = CareManagement.newMemoryAdaptiveProgramCycleStore()
        let item = CareManagement.newAdaptiveProgramCycle("code-926", name: "name-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
