@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalProgramClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalProgramClaimStore = CareManagement.newMemoryGlobalProgramClaimStore()
        let item = CareManagement.newGlobalProgramClaim("code-711", title: "title-221")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
