@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardBudgetStore = BedManagement.newMemoryBedBoardBudgetStore()
        let item = BedManagement.newBedBoardBudget("code-93", name: "name-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
