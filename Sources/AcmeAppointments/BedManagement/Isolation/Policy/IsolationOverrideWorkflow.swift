import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation overrides through their life cycle and keeps a journal of what it did.
    final class IsolationOverrideDesk {
        var store: any IsolationOverrideStore
        var validator: IsolationOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: IsolationOverrideEngine

        init(store: any IsolationOverrideStore, validator: IsolationOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: IsolationOverrideEngine) {
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
                throw Kit.Failure("isolation override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation override \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newIsolationOverrideDesk(_ store: any IsolationOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> IsolationOverrideDesk {
        return IsolationOverrideDesk(
            store: store,
            validator: defaultIsolationOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultIsolationOverrideEngine(flags)
        )
    }
}
