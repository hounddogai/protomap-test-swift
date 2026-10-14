@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusRuleStore = BedManagement.newMemoryCensusRuleStore()
        let item = BedManagement.newCensusRule("code-6", name: "name-435")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
