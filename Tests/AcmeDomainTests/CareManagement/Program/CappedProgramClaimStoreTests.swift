@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedProgramClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedProgramClaimStore = CareManagement.newMemoryCappedProgramClaimStore()
        let item = CareManagement.newCappedProgramClaim("code-77", title: "title-528")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
