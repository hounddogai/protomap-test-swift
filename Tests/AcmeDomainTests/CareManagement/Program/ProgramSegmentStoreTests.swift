@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramSegmentStore = CareManagement.newMemoryProgramSegmentStore()
        let item = CareManagement.newProgramSegment("code-272", name: "name-605")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
