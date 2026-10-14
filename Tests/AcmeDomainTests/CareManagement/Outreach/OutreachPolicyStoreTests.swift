@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachPolicyStore = CareManagement.newMemoryOutreachPolicyStore()
        let item = CareManagement.newOutreachPolicy("code-805", title: "title-30")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
