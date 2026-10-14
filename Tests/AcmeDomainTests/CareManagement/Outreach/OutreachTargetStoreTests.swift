@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachTargetStore = CareManagement.newMemoryOutreachTargetStore()
        let item = CareManagement.newOutreachTarget("code-863", title: "title-988")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
