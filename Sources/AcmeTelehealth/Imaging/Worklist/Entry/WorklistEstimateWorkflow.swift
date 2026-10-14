import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist estimates through their life cycle and keeps a journal of what it did.
    final class WorklistEstimateService {
        var store: any WorklistEstimateStore
        var validator: WorklistEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistEstimateStore, validator: WorklistEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newWorklistEstimateService(_ store: any WorklistEstimateStore, clock: any Kit.Clocks.Clock) -> WorklistEstimateService {
        return WorklistEstimateService(
            store: store,
            validator: defaultWorklistEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
