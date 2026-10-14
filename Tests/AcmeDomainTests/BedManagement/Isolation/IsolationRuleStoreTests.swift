@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationRuleStore = BedManagement.newMemoryIsolationRuleStore()
        let item = BedManagement.newIsolationRule("code-124", title: "title-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
