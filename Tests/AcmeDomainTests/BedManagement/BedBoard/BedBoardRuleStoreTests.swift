@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardRuleStore = BedManagement.newMemoryBedBoardRuleStore()
        let item = BedManagement.newBedBoardRule("code-273", name: "name-61")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
