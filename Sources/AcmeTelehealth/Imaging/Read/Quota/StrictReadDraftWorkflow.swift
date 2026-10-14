import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict read drafts through their life cycle and keeps a journal of what it did.
    final class StrictReadDraftManager {
        var store: any StrictReadDraftStore
        var validator: StrictReadDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictReadDraftEngine

        init(store: any StrictReadDraftStore, validator: StrictReadDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictReadDraftEngine) {
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
                throw Kit.Failure("strict read draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictReadDraftStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict read draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictReadDraftStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict read draft \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newStrictReadDraftManager(_ store: any StrictReadDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictReadDraftManager {
        return StrictReadDraftManager(
            store: store,
            validator: defaultStrictReadDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictReadDraftEngine(flags)
        )
    }
}
