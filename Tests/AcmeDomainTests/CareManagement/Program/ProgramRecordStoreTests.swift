@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramRecordStore = CareManagement.newMemoryProgramRecordStore()
        let item = CareManagement.newProgramRecord("code-37", label: "label-989")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
