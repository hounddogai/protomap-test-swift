@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanWindowStore = BedManagement.newMemoryDischargePlanWindowStore()
        let item = BedManagement.newDischargePlanWindow("code-437", name: "name-628")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
