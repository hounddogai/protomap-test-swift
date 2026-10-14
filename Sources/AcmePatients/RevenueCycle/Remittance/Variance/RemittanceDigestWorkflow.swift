import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance digests through their life cycle and keeps a journal of what it did.
    final class RemittanceDigestDesk {
        var store: any RemittanceDigestStore
        var validator: RemittanceDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceDigestEngine

        init(store: any RemittanceDigestStore, validator: RemittanceDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceDigestEngine) {
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
                throw Kit.Failure("remittance digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance digest \(code) not found")
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

    static func newRemittanceDigestDesk(_ store: any RemittanceDigestStore, clock: any Kit.Clocks.Clock) -> RemittanceDigestDesk {
        return RemittanceDigestDesk(
            store: store,
            validator: defaultRemittanceDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceDigestEngine()
        )
    }
}
