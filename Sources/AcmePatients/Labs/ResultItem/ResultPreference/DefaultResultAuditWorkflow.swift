import AcmePlatform
import Foundation

extension Labs {
    /// Moves default result audits through their life cycle and keeps a journal of what it did.
    final class DefaultResultAuditDesk {
        var store: any DefaultResultAuditStore
        var validator: DefaultResultAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultResultAuditEngine

        init(store: any DefaultResultAuditStore, validator: DefaultResultAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultResultAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default result audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultResultAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default result audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultResultAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default result audit \(code) not found")
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

    static func newDefaultResultAuditDesk(_ store: any DefaultResultAuditStore, clock: any Kit.Clocks.Clock) -> DefaultResultAuditDesk {
        return DefaultResultAuditDesk(
            store: store,
            validator: defaultDefaultResultAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultResultAuditEngine()
        )
    }
}
