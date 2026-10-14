@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackAuthorizationAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackAuthorizationAssignmentStore = RevenueCycle.newMemoryFallbackAuthorizationAssignmentStore()
        let item = RevenueCycle.newFallbackAuthorizationAssignment("code-427", title: "title-108")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
