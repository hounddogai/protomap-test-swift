import AcmePlatform
import Foundation

extension Imaging {
    /// Moves default care protocol audits through their life cycle and keeps a journal of what it did.
    final class DefaultCareProtocolAuditManager {
        var store: any DefaultCareProtocolAuditStore
        var validator: DefaultCareProtocolAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCareProtocolAuditEngine

        init(store: any DefaultCareProtocolAuditStore, validator: DefaultCareProtocolAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCareProtocolAuditEngine) {
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
                throw Kit.Failure("default care protocol audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCareProtocolAuditStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCareProtocolAuditStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol audit \(code) not found")
            }
            let result = engine.price(item)
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

    static func newDefaultCareProtocolAuditManager(_ store: any DefaultCareProtocolAuditStore, clock: any Kit.Clocks.Clock) -> DefaultCareProtocolAuditManager {
        return DefaultCareProtocolAuditManager(
            store: store,
            validator: defaultDefaultCareProtocolAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCareProtocolAuditEngine()
        )
    }
}
