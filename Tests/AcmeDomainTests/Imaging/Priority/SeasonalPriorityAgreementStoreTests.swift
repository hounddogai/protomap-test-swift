@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalPriorityAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalPriorityAgreementStore = Imaging.newMemorySeasonalPriorityAgreementStore()
        let item = Imaging.newSeasonalPriorityAgreement("code-413", name: "name-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
