import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge segments through their life cycle and keeps a journal of what it did.
    final class ChargeSegmentService {
        var store: any ChargeSegmentStore
        var validator: ChargeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeSegmentEngine

        init(store: any ChargeSegmentStore, validator: ChargeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeSegmentEngine) {
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
                throw Kit.Failure("charge segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge segment \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newChargeSegmentService(_ store: any ChargeSegmentStore, clock: any Kit.Clocks.Clock) -> ChargeSegmentService {
        return ChargeSegmentService(
            store: store,
            validator: defaultChargeSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeSegmentEngine()
        )
    }
}
