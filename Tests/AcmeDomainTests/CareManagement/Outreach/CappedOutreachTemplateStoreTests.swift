@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedOutreachTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedOutreachTemplateStore = CareManagement.newMemoryCappedOutreachTemplateStore()
        let item = CareManagement.newCappedOutreachTemplate("code-105", label: "label-433")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
