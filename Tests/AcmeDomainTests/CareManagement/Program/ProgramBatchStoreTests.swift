@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramBatchStore = CareManagement.newMemoryProgramBatchStore()
        let item = CareManagement.newProgramBatch("code-640", label: "label-55")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
