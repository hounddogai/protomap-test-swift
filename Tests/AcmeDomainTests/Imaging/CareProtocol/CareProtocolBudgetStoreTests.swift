@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolBudgetStore = Imaging.newMemoryCareProtocolBudgetStore()
        let item = Imaging.newCareProtocolBudget("code-988", name: "name-783")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
