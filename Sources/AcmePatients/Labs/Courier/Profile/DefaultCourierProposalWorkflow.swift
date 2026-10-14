import AcmePlatform
import Foundation

extension Labs {
    /// Moves default courier proposals through their life cycle and keeps a journal of what it did.
    final class DefaultCourierProposalManager {
        var store: any DefaultCourierProposalStore
        var validator: DefaultCourierProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCourierProposalEngine

        init(store: any DefaultCourierProposalStore, validator: DefaultCourierProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCourierProposalEngine) {
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
                throw Kit.Failure("default courier proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCourierProposalStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCourierProposalStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier proposal \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newDefaultCourierProposalManager(_ store: any DefaultCourierProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCourierProposalManager {
        return DefaultCourierProposalManager(
            store: store,
            validator: defaultDefaultCourierProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCourierProposalEngine(flags)
        )
    }
}
