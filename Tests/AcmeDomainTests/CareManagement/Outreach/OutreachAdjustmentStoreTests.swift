@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachAdjustmentStore = CareManagement.newMemoryOutreachAdjustmentStore()
        let item = CareManagement.newOutreachAdjustment("code-543", title: "title-834")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
