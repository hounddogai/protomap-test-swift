@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedProgramWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedProgramWindowStore = CareManagement.newMemoryBatchedProgramWindowStore()
        let item = CareManagement.newBatchedProgramWindow("code-349", title: "title-98")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
