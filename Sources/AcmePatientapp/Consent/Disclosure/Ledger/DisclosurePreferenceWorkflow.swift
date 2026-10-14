import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure preferences through their life cycle and keeps a journal of what it did.
    final class DisclosurePreferenceCoordinator {
        var store: any DisclosurePreferenceStore
        var validator: DisclosurePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosurePreferenceEngine

        init(store: any DisclosurePreferenceStore, validator: DisclosurePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosurePreferenceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosurePreferenceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosurePreferenceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure preference \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDisclosurePreferenceCoordinator(_ store: any DisclosurePreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DisclosurePreferenceCoordinator {
        return DisclosurePreferenceCoordinator(
            store: store,
            validator: defaultDisclosurePreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosurePreferenceEngine(flags)
        )
    }
}
