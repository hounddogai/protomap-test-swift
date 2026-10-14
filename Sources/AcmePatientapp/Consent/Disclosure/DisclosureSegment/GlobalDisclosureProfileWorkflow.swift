import AcmePlatform
import Foundation

extension Consent {
    /// Moves global disclosure profiles through their life cycle and keeps a journal of what it did.
    final class GlobalDisclosureProfileWorkflow {
        var store: any GlobalDisclosureProfileStore
        var validator: GlobalDisclosureProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalDisclosureProfileEngine

        init(store: any GlobalDisclosureProfileStore, validator: GlobalDisclosureProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalDisclosureProfileEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global disclosure profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalDisclosureProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global disclosure profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalDisclosureProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global disclosure profile \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newGlobalDisclosureProfileWorkflow(_ store: any GlobalDisclosureProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalDisclosureProfileWorkflow {
        return GlobalDisclosureProfileWorkflow(
            store: store,
            validator: defaultGlobalDisclosureProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalDisclosureProfileEngine(flags)
        )
    }
}
