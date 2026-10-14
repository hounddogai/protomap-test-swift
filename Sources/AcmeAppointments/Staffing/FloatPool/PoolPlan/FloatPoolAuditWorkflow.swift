import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool audits through their life cycle and keeps a journal of what it did.
    final class FloatPoolAuditDesk {
        var store: any FloatPoolAuditStore
        var validator: FloatPoolAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolAuditEngine

        init(store: any FloatPoolAuditStore, validator: FloatPoolAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolAuditEngine) {
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
                throw Kit.Failure("float pool audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool audit \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFloatPoolAuditDesk(_ store: any FloatPoolAuditStore, clock: any Kit.Clocks.Clock) -> FloatPoolAuditDesk {
        return FloatPoolAuditDesk(
            store: store,
            validator: defaultFloatPoolAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolAuditEngine()
        )
    }
}
