import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure bundles through their life cycle and keeps a journal of what it did.
    final class DisclosureBundleWorkflow {
        var store: any DisclosureBundleStore
        var validator: DisclosureBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DisclosureBundleStore, validator: DisclosureBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("disclosure bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureBundleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureBundleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newDisclosureBundleWorkflow(_ store: any DisclosureBundleStore, clock: any Kit.Clocks.Clock) -> DisclosureBundleWorkflow {
        return DisclosureBundleWorkflow(
            store: store,
            validator: defaultDisclosureBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
