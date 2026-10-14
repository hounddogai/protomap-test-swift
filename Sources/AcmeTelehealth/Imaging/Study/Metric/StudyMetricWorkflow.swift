import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study metrics through their life cycle and keeps a journal of what it did.
    final class StudyMetricService {
        var store: any StudyMetricStore
        var validator: StudyMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudyMetricEngine

        init(store: any StudyMetricStore, validator: StudyMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudyMetricEngine) {
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
                throw Kit.Failure("study metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudyMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudyMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study metric \(code) not found")
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

    static func newStudyMetricService(_ store: any StudyMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StudyMetricService {
        return StudyMetricService(
            store: store,
            validator: defaultStudyMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudyMetricEngine(flags)
        )
    }
}
