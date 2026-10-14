@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramCycleStore = CareManagement.newMemoryProgramCycleStore()
        let item = CareManagement.newProgramCycle("code-24", title: "title-4")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
