import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge exceptions through their life cycle and keeps a journal of what it did.
    final class ChargeExceptionCoordinator {
        var store: any ChargeExceptionStore
        var validator: ChargeExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeExceptionEngine

        init(store: any ChargeExceptionStore, validator: ChargeExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeExceptionEngine) {
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
                throw Kit.Failure("charge exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge exception \(code) not found")
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

    static func newChargeExceptionCoordinator(_ store: any ChargeExceptionStore, clock: any Kit.Clocks.Clock) -> ChargeExceptionCoordinator {
        return ChargeExceptionCoordinator(
            store: store,
            validator: defaultChargeExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeExceptionEngine()
        )
    }
}
