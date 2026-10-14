import AcmePlatform
import Foundation

extension Imaging {
    /// Moves fallback care protocol audits through their life cycle and keeps a journal of what it did.
    final class FallbackCareProtocolAuditDesk {
        var store: any FallbackCareProtocolAuditStore
        var validator: FallbackCareProtocolAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCareProtocolAuditEngine

        init(store: any FallbackCareProtocolAuditStore, validator: FallbackCareProtocolAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCareProtocolAuditEngine) {
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
                throw Kit.Failure("fallback care protocol audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCareProtocolAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCareProtocolAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol audit \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newFallbackCareProtocolAuditDesk(_ store: any FallbackCareProtocolAuditStore, clock: any Kit.Clocks.Clock) -> FallbackCareProtocolAuditDesk {
        return FallbackCareProtocolAuditDesk(
            store: store,
            validator: defaultFallbackCareProtocolAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCareProtocolAuditEngine()
        )
    }
}
