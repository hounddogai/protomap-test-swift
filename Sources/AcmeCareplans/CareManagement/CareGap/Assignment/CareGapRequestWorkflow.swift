import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap requests through their life cycle and keeps a journal of what it did.
    final class CareGapRequestManager {
        var store: any CareGapRequestStore
        var validator: CareGapRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapRequestEngine

        init(store: any CareGapRequestStore, validator: CareGapRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapRequestEngine) {
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
                throw Kit.Failure("care gap request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapRequestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapRequestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap request \(code) not found")
            }
            let result = engine.price(item)
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

    static func newCareGapRequestManager(_ store: any CareGapRequestStore, clock: any Kit.Clocks.Clock) -> CareGapRequestManager {
        return CareGapRequestManager(
            store: store,
            validator: defaultCareGapRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapRequestEngine()
        )
    }
}
