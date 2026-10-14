import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap allocations through their life cycle and keeps a journal of what it did.
    final class CareGapAllocationService {
        var store: any CareGapAllocationStore
        var validator: CareGapAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapAllocationEngine

        init(store: any CareGapAllocationStore, validator: CareGapAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapAllocationEngine) {
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
                throw Kit.Failure("care gap allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap allocation \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCareGapAllocationService(_ store: any CareGapAllocationStore, clock: any Kit.Clocks.Clock) -> CareGapAllocationService {
        return CareGapAllocationService(
            store: store,
            validator: defaultCareGapAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapAllocationEngine()
        )
    }
}
