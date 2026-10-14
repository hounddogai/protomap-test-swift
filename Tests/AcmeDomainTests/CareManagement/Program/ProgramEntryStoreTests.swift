@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramEntryStore = CareManagement.newMemoryProgramEntryStore()
        let item = CareManagement.newProgramEntry("code-714", label: "label-550")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
