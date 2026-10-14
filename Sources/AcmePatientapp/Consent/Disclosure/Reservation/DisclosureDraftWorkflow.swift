import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure drafts through their life cycle and keeps a journal of what it did.
    final class DisclosureDraftWorkflow {
        var store: any DisclosureDraftStore
        var validator: DisclosureDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureDraftStore, validator: DisclosureDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newDisclosureDraftWorkflow(_ store: any DisclosureDraftStore, clock: any Kit.Clocks.Clock) -> DisclosureDraftWorkflow {
        return DisclosureDraftWorkflow(
            store: store,
            validator: defaultDisclosureDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
