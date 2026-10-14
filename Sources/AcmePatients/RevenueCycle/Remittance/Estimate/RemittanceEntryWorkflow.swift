import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance entries through their life cycle and keeps a journal of what it did.
    final class RemittanceEntryService {
        var store: any RemittanceEntryStore
        var validator: RemittanceEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceEntryEngine

        init(store: any RemittanceEntryStore, validator: RemittanceEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceEntryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceEntryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRemittanceEntryService(_ store: any RemittanceEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceEntryService {
        return RemittanceEntryService(
            store: store,
            validator: defaultRemittanceEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceEntryEngine(flags)
        )
    }
}
