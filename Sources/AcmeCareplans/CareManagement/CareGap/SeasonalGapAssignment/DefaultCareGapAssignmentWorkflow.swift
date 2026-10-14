import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves default care gap assignments through their life cycle and keeps a journal of what it did.
    final class DefaultCareGapAssignmentCoordinator {
        var store: any DefaultCareGapAssignmentStore
        var validator: DefaultCareGapAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCareGapAssignmentEngine

        init(store: any DefaultCareGapAssignmentStore, validator: DefaultCareGapAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCareGapAssignmentEngine) {
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
                throw Kit.Failure("default care gap assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCareGapAssignmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care gap assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCareGapAssignmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care gap assignment \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newDefaultCareGapAssignmentCoordinator(_ store: any DefaultCareGapAssignmentStore, clock: any Kit.Clocks.Clock) -> DefaultCareGapAssignmentCoordinator {
        return DefaultCareGapAssignmentCoordinator(
            store: store,
            validator: defaultDefaultCareGapAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCareGapAssignmentEngine()
        )
    }
}
